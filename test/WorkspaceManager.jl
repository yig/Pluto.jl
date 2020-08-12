using Test
import Pluto: update_save_run!, WorkspaceManager, ClientSession, ServerSession, Notebook, Cell

@testset "Workspace manager" begin
# basic functionality is already tested by the reactivity tests
    🍭 = ServerSession()

    @testset "Multiple notebooks" begin

        fakeclientA = ClientSession(:fakeA, nothing)
        fakeclientB = ClientSession(:fakeB, nothing)
        🍭.connected_clients[fakeclientA.id] = fakeclientA
        🍭.connected_clients[fakeclientB.id] = fakeclientB


        notebookA = Notebook([
            Cell("x = 3")
        ])
        fakeclientA.connected_notebook = notebookA

        notebookB = Notebook([
            Cell("x")
        ])
        fakeclientB.connected_notebook = notebookB

        @test notebookA.path != notebookB.path

        update_save_run!(🍭, notebookA, notebookA.cells[1])
        update_save_run!(🍭, notebookB, notebookB.cells[1])

        @test notebookB.cells[1].errored == true

        WorkspaceManager.unmake_workspace.([notebookA, notebookB])
    end
    @testset "include & ingredients" begin
        client = ClientSession(:faker, nothing)
        
        script1 = tempname() * ".jl"
        script2 = tempname() * ".jl"
        write(script1, """
        x = 1
        f(x) = x
        """)
        write(script2, """
        y = 2
        include("./$(script1)")
        z = x + f(y)
        """)

        script3 = tempname() * ".jl"
        
        write(script3, """
        module M
            🎈 = 2
        end
        """)

        @testset "include illegal" begin
            notebook = Notebook([
                Cell("""include("./$(script1)")"""),
            ], tempname() * ".jl")
            client.connected_notebook = notebook
            update_save_run!(🍭, notebook, notebook.cells[1])
            @test notebook.cells[1].errored === true
            @test occursin("UndefVarError: include", notebook.cells[1].output_repr)

            WorkspaceManager.unmake_workspace(notebook)
        end
    end
end